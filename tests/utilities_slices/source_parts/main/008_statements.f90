do nlag=-n-1,n+1
   call lag_good_data(nlag,xvec,tf,yvec,ygood,ydefault=-999.0_dp)
   write (*,"(/,'nlag = ',i0)") nlag
   write (*,"(100a7)") "i","xgood","ygood","xx","yy"
   do i=1,n
      write (*,"(i7,2l7,2f7.1)") i,tf(i),ygood(i),xvec(i),yvec(i)
   end do
end do
print*,intersection(["a","c","d"],["b","c","a"])
print*,num_matching_char("dog,cat,boy,,",",")
call print_matrix_simple(random_matrix(2,3))
call print_matrix_simple(add_constant_columns(random_matrix(2,3),[5.0_dp,6.0_dp]))
print*,factorial([-1,0,1,2,3,4])
print*,choose(4,[0,1,2,3,4,5])
print*,"#missing",num_missing([10],[2,3,4,5,6]),num_missing([2,4,6],[2,3,4,5,6])
call check_all_equal([3,3],"in xutil, elements ")
call check_all_equal([2,3],"in xutil, elements ")
