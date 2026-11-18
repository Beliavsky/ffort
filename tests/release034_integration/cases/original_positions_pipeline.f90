! Synthetic driver/reporting around exact original bodies in support module.
program main
use original_positions
implicit none
integer,allocatable::selected(:),bounded(:)
selected=positions_char_string(string='a a ',char=' ')
call assert_le(size(selected),2,'positions','limit','pipeline')
call report(selected)
selected=positions_char_string('AAAA','a')
call report(selected)
selected=positions_char_string('banana','a')
call set_alloc_int_vec(selected,bounded,jmin=3,jmax=5)
call assert_le(size(bounded),1,'bounded','limit','pipeline')
call report(bounded)
contains
subroutine report(char)
integer,allocatable,intent(in)::char(:)
integer::work(size(char)),j
character(len=size(char))::label
character(len=32)::record
integer,save::calls=0
calls=calls+1
work=char
label='x '
write(record,'("[",2(a),"]")') label,' '
write(*,'("call=",i0,2(1x,a))')calls,'record',trim(record)
write(*,'("positions:",2(1x,i0))')work
end subroutine
end program
