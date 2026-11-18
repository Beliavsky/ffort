program main
use original_sort
implicit none
real(dp)::a(8),before(8),empty(0)
integer::order(8),seen(8),zero(0),i
before=[4.0_dp,-2.0_dp,4.0_dp,0.0_dp,7.0_dp,-2.0_dp,1.0_dp,4.0_dp]
a=before
call quick_sort(a,order)
if(any(a/=[-2.0_dp,-2.0_dp,0.0_dp,1.0_dp,4.0_dp,4.0_dp,4.0_dp,7.0_dp]))error stop 1
seen=0
do i=1,8
if(order(i)<1.or.order(i)>8)error stop 2
seen(order(i))=seen(order(i))+1
if(a(i)/=before(order(i)))error stop 3
end do
if(any(seen/=1))error stop 4
write(*,'("sorted:",8(1x,i0))')int(a)
write(*,'("checked:",2(1x,i0))')size(a),sum(order)
call quick_sort(empty,zero)
write(*,'("empty:",1x,i0)')size(zero)
before=a
call quick_sort(a,order)
if(any(a/=before))error stop 5
seen=0
do i=1,8
if(order(i)<1.or.order(i)>8)error stop 6
seen(order(i))=seen(order(i))+1
if(a(i)/=before(order(i)))error stop 7
end do
if(any(seen/=1))error stop 8
write(*,'("repeat:",8(1x,i0))')int(a)
end program
