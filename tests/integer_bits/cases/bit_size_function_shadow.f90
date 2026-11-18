program p
print *,bit_size(7)
contains
integer function bit_size(x)
integer,intent(in)::x
bit_size=x+1
end function
end program
