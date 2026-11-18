program p
implicit none
integer::index=2,len_trim=3,adjustl=5,adjustr=7
print *,index,len_trim,adjustl,adjustr
index=index+len_trim+adjustl+adjustr
print *,index
end program
