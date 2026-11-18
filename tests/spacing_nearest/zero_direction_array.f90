program p
implicit none

real::s(3)
s=[1.,0.,1.]
print *,'retained'
print *,99,nearest([1.,1.,1.],s)
end program
