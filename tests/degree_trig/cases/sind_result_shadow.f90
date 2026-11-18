program p
print *,f(7)
contains
integer function f(i) result(sind)
integer,intent(in)::i
sind=i+1
end function
end program
