/*
Copyright 2021 Red Hat OpenShift Data Foundation.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controllers

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"

	operatorv1alpha1 "github.com/operator-framework/api/pkg/operators/v1alpha1"
	odfv1alpha1 "github.com/red-hat-storage/odf-operator/api/v1alpha1"
)

func TestEnsureSubscription(t *testing.T) {

	testCases := []struct {
		label                    string
		kind                     odfv1alpha1.StorageKind
		subscriptionAlreadyExist bool
	}{
		{
			label:                    "create subscription(s) for StorageVendors if none exist",
			subscriptionAlreadyExist: false,
		},
		{
			label:                    "update subscription(s) for StorageVendors if exist",
			subscriptionAlreadyExist: true,
		},
	}

	for i, tc := range testCases {
		t.Logf("Case %d: %s\n", i+1, tc.label)

		for _, kind := range KnownKinds {
			var err error

			fakeStorageSystem := GetFakeStorageSystem(kind)
			fakeReconciler := GetFakeStorageSystemReconciler(t, fakeStorageSystem)
			subs := GetSubscriptions(kind)

			if tc.subscriptionAlreadyExist {
				for _, subscription := range subs {
					sub := subscription.DeepCopy()
					sub.Spec.Channel = "fake-channel"
					err = fakeReconciler.Client.Create(context.TODO(), sub)
					assert.NoError(t, err)
				}
			}

			odfSub := &operatorv1alpha1.Subscription{
				ObjectMeta: metav1.ObjectMeta{
					Name:      "odf-operator",
					Namespace: OperatorNamespace,
				},

				Spec: &operatorv1alpha1.SubscriptionSpec{
					Package: OdfSubscriptionPackage,
					Config: &operatorv1alpha1.SubscriptionConfig{
						Tolerations: []corev1.Toleration{
							{
								Key:      "node.odf.openshift.io/storage",
								Operator: "Equal",
								Value:    "true",
								Effect:   "NoSchedule",
							},
						},
					},
				},
			}
			err = fakeReconciler.Client.Create(context.TODO(), odfSub)
			assert.NoError(t, err)

			err = fakeReconciler.ensureSubscriptions(fakeStorageSystem, fakeReconciler.Log)
			assert.NoError(t, err)

			for _, expectedSubscription := range subs {
				if expectedSubscription.Spec.Config == nil {
					expectedSubscription.Spec.Config = &operatorv1alpha1.SubscriptionConfig{
						Tolerations: odfSub.Spec.Config.Tolerations,
					}
				} else {
					expectedSubscription.Spec.Config.Tolerations = getMergedTolerations(odfSub.Spec.Config.Tolerations, expectedSubscription.Spec.Config.Tolerations)
				}

				actualSubscription := &operatorv1alpha1.Subscription{}
				err = fakeReconciler.Client.Get(context.TODO(), types.NamespacedName{Name: expectedSubscription.Name, Namespace: expectedSubscription.Namespace}, actualSubscription)
				assert.NoError(t, err)

				assert.Equal(t, expectedSubscription.Spec, actualSubscription.Spec)
			}
		}
	}
}
