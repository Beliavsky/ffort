program p
implicit none
integer::i,a(3)
forall(i=1:3,f(i)>0) a(i)=i
contains
integer function f(x)
integer,intent(in)::x
f=x
end function
end program
