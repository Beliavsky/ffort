program p
print *,f(7)
contains
integer function f(i) result(asind)
integer,intent(in)::i
asind=i+1
end function
end program
