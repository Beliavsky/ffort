program p
implicit none
character(len=*),parameter::left='(i0'
character(len=*),parameter::fmt=left//",1x,l1)"
integer,parameter::empty(0)=[integer::]
print fmt,size(empty),all(empty==0)
end program
