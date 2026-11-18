module automatic_fixture
implicit none
contains
subroutine work(n)
integer, intent(in) :: n
integer :: aa(max(0,n-1)),bb(abs(-n)),cc(mod(n,3)+1),dd(2**n),ee(n/2)
aa=1
bb=2
cc=3
dd=4
ee=5
print *,size(aa),sum(bb),sum(cc),sum(dd),sum(ee)
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(3)
end program
