program section_oracle
implicit none
integer :: aa(-2:3,4:8),i,j,lo,hi,st,col,cl,ch,cs
do j=4,8
 do i=-2,3
 aa(i,j)=100*j+i
 end do
end do
lo=3
hi=-2
st=-2
cl=8
ch=4
cs=-2
col=6
print *,aa(lo:hi:st,cl:ch:cs)
print *,aa(lo:hi:st,col)
print *,aa(lo,cl:ch:cs)
print *,size(aa(lo:hi:st,cl:ch:cs),1),size(aa(lo:hi:st,cl:ch:cs),2)
aa(lo:hi:st,cl:ch:cs)=17
print *,aa
end program section_oracle
