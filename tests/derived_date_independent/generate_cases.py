#!/usr/bin/env python3
"""Date arithmetic oracle: Python calendar-month arithmetic, independently checked by GNU."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parent
ORIGINAL = ROOT / 'user_exact_month_date.f90'


def generate():
    original = ORIGINAL.read_bytes()
    marker = b'program test_month_date'
    module = original[:original.lower().index(marker)]
    cases = []

    def add(name, body, output='', stop=None):
        source = module + ('program date_edge\n   use month_date_mod\n   implicit none\n' +
                         body + '\nend program date_edge\n').encode()
        destination = ROOT / 'cases' / (name + '.f90')
        destination.parent.mkdir(exist_ok=True)
        destination.write_bytes(source)
        cases.append(dict(name=name, source='cases/' + destination.name,
                          expected_stdout=output, stop=stop))

    exact_output = ('d1 = 2026-11\nd2:\n2025-08\nd1 - d2 (months) = 15\n'
                    'd1 +  3 = 2027-02\n 3 + d1 = 2027-02\nd1 - 14 = 2025-09\n'
                    'after advancing 2026-12 by 2 months: 2027-02\nAll tests passed.\n')
    cases.append(dict(name='user_exact_month_date', source=ORIGINAL.name,
                      expected_stdout=exact_output, stop=None))

    samples = [(0,1,0), (0,1,1), (0,1,119999), (0,12,1),
               (1,1,-1), (1,1,-12), (9999,12,0), (9999,12,-119999),
               (2026,11,3), (2026,11,-14), (2025,1,-14), (2025,12,13),
               (2026,1,-1), (2026,12,2), (2024,2,12), (2000,1,-12000),
               (42,6,10000), (5000,7,-60000), (9998,12,12), (10,1,-120)]
    for number, (year, month, offset) in enumerate(samples):
        index = year * 12 + month - 1 + offset
        result_year, result_month = divmod(index, 12)
        expected = f'{result_year:04d}-{result_month+1:02d}\n'
        add(f'addition_{number:02d}',
            f"   print '(a)', date_string(date_t({year},{month}) + ({offset}))", expected)
        add(f'subtraction_{number:02d}',
            f"   print '(a)', date_string(date_t({year},{month}) - ({-offset}))", expected)
        if number % 2 == 0:
            add(f'inplace_{number:02d}',
                '   type(date_t) :: d\n' + f'   d = date_t({year},{month})\n' +
                f'   call add_months(d, {offset})\n' + "   print '(a)', date_string(d)", expected)

    for number, (a,b) in enumerate([((0,1),(9999,12)), ((9999,12),(0,1)),
                                   ((2026,11),(2025,8)), ((2025,8),(2026,11)),
                                   ((0,1),(0,1)), ((1234,5),(1234,6))]):
        delta = (a[0]-b[0])*12 + a[1]-b[1]
        add(f'difference_{number:02d}',
            f"   print '(i0)', date_t({a[0]},{a[1]}) - date_t({b[0]},{b[1]})", f'{delta}\n')

    for number, (year,month,message) in enumerate([
        (-1,1,'Invalid year: expected 0..9999'), (10000,1,'Invalid year: expected 0..9999'),
        (2026,0,'Invalid month: expected 1..12'), (2026,13,'Invalid month: expected 1..12'),
        (-1,0,'Invalid year: expected 0..9999')]):
        add(f'invalid_date_{number:02d}',
            "   print '(a)', 'BEFORE'\n" +
            f"   print '(a)', date_string(date_t({year},{month}))\n" +
            "   print '(a)', 'AFTER'", 'BEFORE\n', message)

    stops = [('date_t(0,1) + (-1)'), ('date_t(0,1) - 1'),
             ('date_t(9999,12) + 1'), ('date_t(9999,12) - (-1)'),
             ('date_t(2026,11) + 2147483647'),
             ('date_t(2026,11) - 2147483647'),
             ('date_t(2026,11) + (-2147483647 - 1)'),
             ('date_t(2026,11) - (-2147483647 - 1)')]
    for number, expression in enumerate(stops):
        add(f'out_of_range_{number:02d}',
            "   print '(a)', 'BEFORE'\n" + f"   print '(a)', date_string({expression})\n" +
            "   print '(a)', 'AFTER'", 'BEFORE\n', 'Date arithmetic exceeds years 0..9999')

    add('whole_value_copy_independent',
        '   type(date_t) :: a, b\n   a = date_t(2026,11)\n   b = a\n'
        '   a%year = 1999\n   a%month = 1\n'
        "   print '(a)', date_string(a)\n   print '(a)', date_string(b)", '1999-01\n2026-11\n')
    add('inout_copyback',
        '   type(date_t) :: a, b\n   a = date_t(2026,11)\n   b = a\n'
        '   call add_months(b, 3)\n'
        "   print '(a)', date_string(a)\n   print '(a)', date_string(b)", '2026-11\n2027-02\n')
    add('relation_composition',
        '   type(date_t) :: a, b\n   a = date_t(2025,12)\n   b = date_t(2026,1)\n'
        '   if (.not.(a < b .and. a <= b .and. b > a .and. b >= a)) stop 1\n'
        '   if (.not.(a /= b .and. a == a .and. b >= b .and. a <= a)) stop 2\n'
        "   print '(a)', 'relations pass'", 'relations pass\n')

    manifest = dict(description='Independent exact date program and calendar arithmetic/STOP regressions',
                    source_library_file_id='libfile_713593c1d7c88191896eb8102c4d40b9',
                    original_sha256=hashlib.sha256(original).hexdigest(), cases=cases)
    (ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    return manifest


if __name__ == '__main__':
    print(f"Generated {len(generate()['cases'])} date cases")
