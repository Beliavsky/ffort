program p
implicit none
integer::a(3),i
a=seq(3,0)
a=twice(a)+seq(3,10)
print *,a,seq(2,0),seq(4,20)
do i=1,3
print *,sum(seq(i,0))
end do
contains
pure function seq(n,b) result(y)
integer,intent(in)::n,b
integer::y(-1:n-2),j
do j=1,n
y(j-2)=b+j
end do
end function
pure function twice(x) result(y)
integer,intent(in)::x(:)
integer::y(size(x))
y=x+seq(size(x),0)
end function
end program
