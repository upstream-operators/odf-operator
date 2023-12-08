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
	"os"
)

var (
	DefaultValMap = map[string]string{
		"OPERATOR_NAMESPACE": "openshift-storage",

		"NOOBAA_SUBSCRIPTION_NAME":                    "noobaa-operator",
		"NOOBAA_SUBSCRIPTION_PACKAGE":                 "noobaa-operator",
		"NOOBAA_SUBSCRIPTION_CHANNEL":                 "alpha",
		"NOOBAA_SUBSCRIPTION_STARTINGCSV":             "noobaa-operator.v5.14.0",
		"NOOBAA_SUBSCRIPTION_CATALOGSOURCE":           "odf-catalogsource",
		"NOOBAA_SUBSCRIPTION_CATALOGSOURCE_NAMESPACE": "openshift-marketplace",

		"OCS_SUBSCRIPTION_NAME":                    "ocs-operator",
		"OCS_SUBSCRIPTION_PACKAGE":                 "ocs-operator",
		"OCS_SUBSCRIPTION_CHANNEL":                 "alpha",
		"OCS_SUBSCRIPTION_STARTINGCSV":             "ocs-operator.v4.14.0",
		"OCS_SUBSCRIPTION_CATALOGSOURCE":           "odf-catalogsource",
		"OCS_SUBSCRIPTION_CATALOGSOURCE_NAMESPACE": "openshift-marketplace",

		"CSIADDONS_SUBSCRIPTION_NAME":                    "csi-addons",
		"CSIADDONS_SUBSCRIPTION_PACKAGE":                 "csi-addons",
		"CSIADDONS_SUBSCRIPTION_CHANNEL":                 "alpha",
		"CSIADDONS_SUBSCRIPTION_STARTINGCSV":             "csi-addons.v0.7.0",
		"CSIADDONS_SUBSCRIPTION_CATALOGSOURCE":           "odf-catalogsource",
		"CSIADDONS_SUBSCRIPTION_CATALOGSOURCE_NAMESPACE": "openshift-marketplace",

		"IBM_SUBSCRIPTION_NAME":                    "ibm-storage-odf-operator",
		"IBM_SUBSCRIPTION_PACKAGE":                 "ibm-storage-odf-operator",
		"IBM_SUBSCRIPTION_CHANNEL":                 "stable-v1.4",
		"IBM_SUBSCRIPTION_STARTINGCSV":             "ibm-storage-odf-operator.v1.4.1",
		"IBM_SUBSCRIPTION_CATALOGSOURCE":           "odf-catalogsource",
		"IBM_SUBSCRIPTION_CATALOGSOURCE_NAMESPACE": "openshift-marketplace",
	}

	OperatorNamespace = GetEnvOrDefault("OPERATOR_NAMESPACE")

	OcsSubscriptionName                   = GetEnvOrDefault("OCS_SUBSCRIPTION_NAME")
	OcsSubscriptionPackage                = GetEnvOrDefault("OCS_SUBSCRIPTION_PACKAGE")
	OcsSubscriptionChannel                = GetEnvOrDefault("OCS_SUBSCRIPTION_CHANNEL")
	OcsSubscriptionStartingCSV            = GetEnvOrDefault("OCS_SUBSCRIPTION_STARTINGCSV")
	OcsSubscriptionCatalogSource          = GetEnvOrDefault("OCS_SUBSCRIPTION_CATALOGSOURCE")
	OcsSubscriptionCatalogSourceNamespace = GetEnvOrDefault("OCS_SUBSCRIPTION_CATALOGSOURCE_NAMESPACE")

	NoobaaSubscriptionName                   = GetEnvOrDefault("NOOBAA_SUBSCRIPTION_NAME")
	NoobaaSubscriptionPackage                = GetEnvOrDefault("NOOBAA_SUBSCRIPTION_PACKAGE")
	NoobaaSubscriptionChannel                = GetEnvOrDefault("NOOBAA_SUBSCRIPTION_CHANNEL")
	NoobaaSubscriptionStartingCSV            = GetEnvOrDefault("NOOBAA_SUBSCRIPTION_STARTINGCSV")
	NoobaaSubscriptionCatalogSource          = GetEnvOrDefault("NOOBAA_SUBSCRIPTION_CATALOGSOURCE")
	NoobaaSubscriptionCatalogSourceNamespace = GetEnvOrDefault("NOOBAA_SUBSCRIPTION_CATALOGSOURCE_NAMESPACE")

	CSIAddonsSubscriptionName                   = GetEnvOrDefault("CSIADDONS_SUBSCRIPTION_NAME")
	CSIAddonsSubscriptionPackage                = GetEnvOrDefault("CSIADDONS_SUBSCRIPTION_PACKAGE")
	CSIAddonsSubscriptionChannel                = GetEnvOrDefault("CSIADDONS_SUBSCRIPTION_CHANNEL")
	CSIAddonsSubscriptionStartingCSV            = GetEnvOrDefault("CSIADDONS_SUBSCRIPTION_STARTINGCSV")
	CSIAddonsSubscriptionCatalogSource          = GetEnvOrDefault("CSIADDONS_SUBSCRIPTION_CATALOGSOURCE")
	CSIAddonsSubscriptionCatalogSourceNamespace = GetEnvOrDefault("CSIADDONS_SUBSCRIPTION_CATALOGSOURCE_NAMESPACE")

	IbmSubscriptionName                   = GetEnvOrDefault("IBM_SUBSCRIPTION_NAME")
	IbmSubscriptionPackage                = GetEnvOrDefault("IBM_SUBSCRIPTION_PACKAGE")
	IbmSubscriptionChannel                = GetEnvOrDefault("IBM_SUBSCRIPTION_CHANNEL")
	IbmSubscriptionStartingCSV            = GetEnvOrDefault("IBM_SUBSCRIPTION_STARTINGCSV")
	IbmSubscriptionCatalogSource          = GetEnvOrDefault("IBM_SUBSCRIPTION_CATALOGSOURCE")
	IbmSubscriptionCatalogSourceNamespace = GetEnvOrDefault("IBM_SUBSCRIPTION_CATALOGSOURCE_NAMESPACE")
)

const (
	OdfSubscriptionPackage = "odf-operator"
)

func GetEnvOrDefault(env string) string {
	if val := os.Getenv(env); val != "" {
		return val
	}

	return DefaultValMap[env]
}
