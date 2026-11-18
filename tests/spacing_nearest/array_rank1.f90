program p
implicit none

print *,spacing([0.,1.,2.])==[tiny(1.),epsilon(1.),2*epsilon(1.)]
print *,nearest(1d0,[-1.,1.])<1d0
print *,nearest([1.,2.],1d0)>[1.,2.]
end program
