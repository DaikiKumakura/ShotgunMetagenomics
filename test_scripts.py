"""Exercise guards and command propagation with stub tools, not biological data."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

BASH = r'C:\Program Files\Git\bin\bash.exe' if os.name == 'nt' else shutil.which('bash')
SCRIPTS = Path(__file__).parent.resolve()/'Scripts'


class ScriptTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root/'bin').mkdir()

    def tool(self, name, body):
        p = self.root/'bin'/name
        p.write_text('#!/usr/bin/env bash\nset -eu\n'+body+'\n', newline='\n')
        p.chmod(0o755)

    def run_script(self, name):
        env = dict(os.environ)
        # Unix path separators inside the Git Bash process, also valid on Linux.
        def shell_path(p):
            s = p.as_posix()
            return '/'+s[0].lower()+s[2:] if os.name == 'nt' else s
        bindir = shell_path(self.root/'bin')
        cmd = 'export PATH="'+bindir+':$PATH"; bash "'+shell_path(SCRIPTS/name)+'"'
        return subprocess.run([BASH,'-c',cmd], cwd=self.root, env=env, capture_output=True, text=True)

    def paired(self, sample='sample'):
        (self.root/'rawdata').mkdir()
        for n in (1,2):
            (self.root/'rawdata'/f'{sample}_{n}.fastq.gz').write_text('fixture')

    def test_missing_inputs(self):
        for name in ('merged.sh','qc.sh','qc_merged.sh','profile.sh'):
            with self.subTest(name=name):
                self.assertNotEqual(self.run_script(name).returncode,0)

    def test_missing_mate_before_output(self):
        self.paired()
        (self.root/'rawdata/sample_2.fastq.gz').unlink()
        self.assertNotEqual(self.run_script('merged.sh').returncode,0)
        self.assertFalse((self.root/'merged').exists())

    def test_failed_merge_preserves_other_files(self):
        self.paired()
        (self.root/'keep.fastq').write_text('keep')
        self.tool('bbmerge.sh','exit 17')
        self.assertEqual(self.run_script('merged.sh').returncode,17)
        self.assertEqual((self.root/'keep.fastq').read_text(),'keep')

    def test_space_in_sample_name(self):
        self.paired('sample with spaces')
        self.tool('bbmerge.sh','for a in "$@"; do case "$a" in out=*) printf "reads" > "${a#out=}";; esac; done')
        result=self.run_script('merged.sh')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual((self.root/'merged/sample with spaces.fastq').read_text(),'reads')

    def test_existing_output_preserved(self):
        self.paired()
        self.tool('bbmerge.sh','exit 0')
        (self.root/'merged').mkdir()
        (self.root/'merged/keep').write_text('keep')
        self.assertNotEqual(self.run_script('merged.sh').returncode,0)
        self.assertEqual((self.root/'merged/keep').read_text(),'keep')

    def test_failed_qc_stops_without_cleanup(self):
        self.paired()
        (self.root/'ref').mkdir()
        for n in range(6): (self.root/'ref'/f'ref_db.{n}.bt2').write_text('index')
        self.tool('kneaddata','printf "diagnostic" > qc/diagnostic; exit 19')
        self.assertEqual(self.run_script('qc.sh').returncode,19)
        self.assertEqual((self.root/'qc/diagnostic').read_text(),'diagnostic')

    def test_profile_uses_only_final_clean_reads(self):
        (self.root/'qc_merged').mkdir()
        for name in ('a_kneaddata.fastq','a.trimmed.fastq','a.contam.fastq'):
            (self.root/'qc_merged'/name).write_text('reads')
        for p in ('ref_choco/chocophlan','ref_uniref/uniref','ref_map/utility_mapping'):
            (self.root/p).mkdir(parents=True)
        self.tool('humann_config','exit 0')
        self.tool('humann','printf "%s\\n" "$@" >> calls.txt')
        self.tool('humann_join_tables','while (($#)); do if [[ "$1" == -o ]]; then printf "table" > "$2"; break; fi; shift; done')
        self.tool('humann_renorm_table','exit 0')
        result=self.run_script('profile.sh')
        self.assertEqual(result.returncode,0,result.stderr)
        calls=(self.root/'calls.txt').read_text()
        self.assertIn('a_kneaddata.fastq',calls)
        self.assertNotIn('trimmed.fastq',calls)
        self.assertTrue((self.root/'qc_merged/a.contam.fastq').exists())


if __name__=='__main__': unittest.main()
