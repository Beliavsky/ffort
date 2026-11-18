! Synthetic release 0.30 composition fixture; not an extracted utility body.
program composition
implicit none
integer a(2,3)
logical,allocatable :: selected(:,:)
integer(8) first(2)
a=reshape([7,2,7,7,5,7],[2,3])
allocate(selected(-1:0,4:6))
selected=.true.
selected(-1,5)=.false.
selected(0,6)=.false.
first=findloc(back=.false.,value=7,array=a,kind=8,mask=selected)
print *,shape(selected),kind(first),first
print *,findloc(a,7,mask=selected,back=.true.)
print *,findloc(a,7,dim=1,mask=selected),findloc(a,7,dim=2,mask=selected,back=.true.)
print *,findloc(a,7,mask=.false.)
end program
