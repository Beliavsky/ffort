program p
implicit none
print *,shiftr(2,1)
contains
integer function shiftr(i,shift)
integer,intent(in)::i,shift
shiftr=i+100
end function
end program
