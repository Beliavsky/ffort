program p
implicit none
print *,maskr(2)
contains
integer function maskr(i)
integer,intent(in)::i
maskr=i+100
end function
end program
