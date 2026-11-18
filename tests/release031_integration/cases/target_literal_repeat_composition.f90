! Synthetic release 0.31 composition fixture; not an extracted utility body.
program composition
implicit none
character(4),target :: code(3)
integer,target :: lo,hi
logical,allocatable,target :: selected(:)
lo=2;hi=3
code(1)=repeat('0123456789'(lo:hi),2)
code(2)=repeat('0123456789'(3:4),2)
code(3)=code(1)
selected=[.true.,.false.,.true.]
print *,len('0123456789'(lo:hi)),shape(code)
print *,findloc(code,repeat('0123456789'(lo:hi),2),mask=selected,back=.true.)
print '(a)',code(1)
print '(a)',code(2)
end program
