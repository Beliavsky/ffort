program p
implicit none
integer::i,a(4)
forall(i=1:4) a(i)=square(i)
print *,a
contains
pure integer function square(x)
integer,intent(in)::x
square=x*x
end function
end program
