program p
print *,asind(7)
contains
integer function asind(i)
integer,intent(in)::i
asind=i+1
end function
end program
