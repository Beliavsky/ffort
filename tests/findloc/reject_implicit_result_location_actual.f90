program p
integer::a(3)=[3,4,3]
print *,g(findloc(a,3,1))
contains
integer function g(x)
integer,intent(in)::x
g=x
end function
end program
