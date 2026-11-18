program p
implicit none
integer::i,a(2)
forall(i=1:2) a(i)=f(i)
contains
integer function f(x)
integer,intent(in)::x
f=x
end function
end program
