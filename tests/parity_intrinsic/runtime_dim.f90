program p
implicit none
logical::a(2,3)
integer::n
a=.true.
n=2
call show(a,n)
contains
subroutine show(x,n)
logical,intent(in)::x(:,:)
integer,intent(in)::n
print *,parity(x,dim=n)
end subroutine
end program
