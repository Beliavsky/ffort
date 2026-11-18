program demo
implicit none
integer::a(2,2,3),k
do k=1,3
 a(:,:,k)=k
end do
where(a(1,:,3:1:-1)>1)
 a(2,:,3:1:-1)=a(1,:,3:1:-1)*10
elsewhere
 a(2,:,3:1:-1)=-1
end where
print *,a
end program
