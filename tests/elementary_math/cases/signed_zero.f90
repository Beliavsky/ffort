program p
implicit none
print *,sign(1.,-0.),sign(1d0,-0d0),sign(-1.,0.),sign(-1d0,0d0)
print *,sign(1d0,sign(0d0,-1d0)),sign(1d0,sign(-0d0,1d0))
end program
