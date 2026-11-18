program p
print *,f(7)
contains
integer function f(i) result(acosd)
integer,intent(in)::i
acosd=i+1
end function
end program
