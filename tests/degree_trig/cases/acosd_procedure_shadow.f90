program p
print *,acosd(7)
contains
integer function acosd(i)
integer,intent(in)::i
acosd=i+1
end function
end program
