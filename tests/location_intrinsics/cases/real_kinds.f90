program p
implicit none

print *,minloc([2.0,-1.0,3.0]),maxloc([2.0d0,-1.0d0,3.0d0]),kind(maxloc([1.0d0]))
end program
