program p
implicit none
integer::a(3)
a=seq(3,10)
print *,a,seq(b=0,n=2),size(seq(0,5)),size(seq(-2,5)),lbound(seq(3,5),1),ubound(seq(3,5),1)
contains
pure function seq(n,b) result(y)
integer,intent(in)::n,b
integer::y(-1:n-2),j
do j=1,n
y(j-2)=b+j
end do
end function
end program
