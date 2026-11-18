function count_rows(tf_mat) result(ntrue)
logical, intent(in) :: tf_mat(:,:)
integer             :: ntrue(size(tf_mat,1))
integer             :: i,n
n = size(tf_mat,1)
forall (i=1:n) ntrue(i) = count(tf_mat(i,:))
end function count_rows
!
