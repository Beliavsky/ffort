program p
implicit none

print *,maxloc(back=.true.,kind=8,mask=[.false.,.true.,.true.],array=[3,2,2]),minloc(mask=.true.,array=[3,2,1],dim=1)
end program
