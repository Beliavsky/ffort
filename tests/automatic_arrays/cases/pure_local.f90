module automatic_fixture
implicit none
contains
pure subroutine work(n,answer)
integer,intent(in)::n
integer,intent(out)::answer
integer::aa(n)
aa=5
answer=sum(aa)
end subroutine

end module
program demo
use automatic_fixture
implicit none
integer::v
call work(4,v)
print *,v
end program
