program p
implicit none
character(*),parameter::fmt='(i0,'//repeat('i0,',1)//'i0)'
print fmt,1,2,3
end program
