program p
implicit none
integer::a(3,3,3),idx(3)
a=1
idx=[3,1,2]
where(a>0)a=a(:,:,idx)
end program
