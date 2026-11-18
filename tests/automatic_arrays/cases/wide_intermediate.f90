program demo
implicit none
call work(4294967296_8)
contains
subroutine work(n)
integer(kind=8),intent(in)::n
integer::aa(n/2147483648_8)
aa=3
print *,size(aa),sum(aa)
end subroutine
end program
