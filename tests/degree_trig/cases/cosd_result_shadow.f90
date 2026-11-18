program p
print *,f(7)
contains
integer function f(i) result(cosd)
integer,intent(in)::i
cosd=i+1
end function
end program
