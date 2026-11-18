program p
implicit none
print *,maskl(2)
contains
integer function maskl(i)
integer,intent(in)::i
maskl=i+100
end function
end program
