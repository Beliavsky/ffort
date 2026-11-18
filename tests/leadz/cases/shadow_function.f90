program p
implicit none
print *,leadz(1_8)
contains
function leadz(i) result(x)
integer(8),intent(in)::i
integer(8)::x
x=i+100_8
end function
end program
