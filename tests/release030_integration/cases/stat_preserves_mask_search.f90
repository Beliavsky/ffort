! Synthetic release 0.30 composition fixture; not an extracted utility body.
program composition
implicit none
logical,allocatable :: selected(:,:)
integer values(2,2),status
allocate(selected(-1:0,4:5))
selected=reshape([.true.,.false.,.false.,.true.],[2,2])
allocate(selected(1,1),stat=status)
print *,status/=0,allocated(selected),shape(selected),lbound(selected,1),lbound(selected,2)
print *,findloc(selected,.true.),findloc(selected,.true.,back=.true.)
values=2
where(selected) values=9
print *,sum(values)
deallocate(selected,stat=status)
print *,status,allocated(selected)
end program
