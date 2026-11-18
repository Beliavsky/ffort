program control
implicit none
print *,f(3),g(4)
contains
integer function f(n) result(x)
integer,intent(in)::n
integer::i
x=0
same: do i=1,n
 if(i==2) cycle same
 x=x+i
end do same
end function
integer function g(n) result(x)
integer,intent(in)::n
integer::i
x=0
same: do i=1,n
 if(i==3) exit same
 x=x+i
end do same
end function
end program
