program p
print *,cosd(7)
contains
integer function cosd(i)
integer,intent(in)::i
cosd=i+1
end function
end program
