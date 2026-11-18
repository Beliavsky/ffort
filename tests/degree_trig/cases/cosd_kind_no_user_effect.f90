program p
print *,kind(cosd(f()))
contains
real(8) function f()
real(8)::z
z=0d0
f=1d0/z
end function
end program
