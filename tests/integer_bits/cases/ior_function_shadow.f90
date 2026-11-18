program p
print *,ior(7)
contains
integer function ior(x)
integer,intent(in)::x
ior=x+1
end function
end program
