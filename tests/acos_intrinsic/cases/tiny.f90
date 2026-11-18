program p
implicit none

print *,acos(tiny(1.0)),acos(tiny(1d0)),acos(-0.0),acos(-0d0)
end program
