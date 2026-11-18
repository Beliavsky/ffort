program p
implicit none

print *,minloc([2,1,0],[.true.,.false.,.true.]),maxloc([2,3,2],[.true.,.false.,.true.],kind=8,back=.true.)
end program
