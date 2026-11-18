program p
implicit none
integer::index(3)=[2,4,6],len_trim(2)=[7,9]
integer::adjustl(2)=[3,5],adjustr(2)=[8,10]
print *,index(2),len_trim(2),adjustl(1),adjustr(2)
index(2)=len_trim(1)+adjustl(2)
print *,index
end program
