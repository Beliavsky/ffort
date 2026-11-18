program p
implicit none

print *,acos(-1.0),acos(0.0),acos(1.0)
print *,acos(-1d0),acos(0d0),acos(1d0)
print *,kind(acos(0.)),kind(acos(0d0))
end program
