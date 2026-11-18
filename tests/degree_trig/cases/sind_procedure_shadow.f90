program p
print *,sind(7)
contains
integer function sind(i)
integer,intent(in)::i
sind=i+1
end function
end program
