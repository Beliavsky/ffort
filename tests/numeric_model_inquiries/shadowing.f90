module shadow_model
implicit none
contains
integer function epsilon(x)
integer,intent(in)::x
epsilon=x+3
end function
end module
program model_shadowing
use shadow_model
implicit none
integer::radix(2)=[10,20],huge(2)=[30,40]
real::tiny=3.0
print *,epsilon(4),radix(2),huge(1),tiny
end program
